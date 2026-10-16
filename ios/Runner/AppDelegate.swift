import Flutter
import MapKit
import UIKit

@main
@objc @MainActor class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BikeTrackRecorder")!
    let flutterApi = RecorderFlutterApi(binaryMessenger: registrar.messenger())
    RideRecorder.shared.connect(flutterApi: flutterApi)
    RecorderHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: RideRecorder.shared
    )
    let maps = RouteMapRegistry()
    registrar.register(maps, withId: "biketrack/route-map")
    RouteMapHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: maps)
  }
}

private enum RouteMapDefaults {
  static let center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  static let span = MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 180)
  static let padding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
  static let lineWidth: CGFloat = 4
  static let singlePointSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
  static let minimumMapPoints = 10_000.0
}

private final class RouteMapRegistry: NSObject, FlutterPlatformViewFactory, RouteMapHostApi {
  private var views: [Int64: WeakRouteMapView] = [:]

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let view = RouteMapPlatformView(frame: frame)
    views[viewId] = WeakRouteMapView(view)
    return view
  }

  func updateRoute(viewId: Int64, pieces: [MapRoutePiece]) throws {
    guard let view = views[viewId]?.value else {
      views.removeValue(forKey: viewId)
      throw PigeonError(code: "map_view_missing", message: "Route view is no longer available", details: nil)
    }
    view.update(pieces)
  }
}

private final class WeakRouteMapView {
  weak var value: RouteMapPlatformView?
  init(_ value: RouteMapPlatformView) { self.value = value }
}

private final class RouteMapPlatformView: NSObject, FlutterPlatformView, MKMapViewDelegate {
  private let map: MKMapView

  init(frame: CGRect) {
    map = MKMapView(frame: frame)
    super.init()
    map.delegate = self
    map.showsUserLocation = true
    map.setRegion(MKCoordinateRegion(center: RouteMapDefaults.center, span: RouteMapDefaults.span), animated: false)
  }

  func view() -> UIView { map }

  func update(_ pieces: [MapRoutePiece]) {
    map.removeOverlays(map.overlays)
    let coordinates = pieces.flatMap { piece in
      piece.points.compactMap { point -> CLLocationCoordinate2D? in
        guard point.latitudeDeg.isFinite, point.longitudeDeg.isFinite,
              (-90...90).contains(point.latitudeDeg), (-180...180).contains(point.longitudeDeg) else { return nil }
        return CLLocationCoordinate2D(latitude: point.latitudeDeg, longitude: point.longitudeDeg)
      }
    }
    for piece in pieces {
      let points = piece.points.map {
        CLLocationCoordinate2D(latitude: $0.latitudeDeg, longitude: $0.longitudeDeg)
      }.filter { CLLocationCoordinate2DIsValid($0) }
      if points.count >= 2 {
        map.addOverlay(MKPolyline(coordinates: points, count: points.count))
      }
    }
    guard !coordinates.isEmpty else {
      map.setRegion(MKCoordinateRegion(center: RouteMapDefaults.center, span: RouteMapDefaults.span), animated: false)
      return
    }
    let mapPoints = coordinates.map(MKMapPoint.init)
    let minX = mapPoints.map(\.x).min()!
    let maxX = mapPoints.map(\.x).max()!
    let minY = mapPoints.map(\.y).min()!
    let maxY = mapPoints.map(\.y).max()!
    if minX == maxX && minY == maxY {
      map.setRegion(MKCoordinateRegion(center: coordinates[0], span: RouteMapDefaults.singlePointSpan), animated: false)
    } else {
      let width = max(maxX - minX, RouteMapDefaults.minimumMapPoints)
      let height = max(maxY - minY, RouteMapDefaults.minimumMapPoints)
      let rect = MKMapRect(
        x: minX - (width - (maxX - minX)) / 2,
        y: minY - (height - (maxY - minY)) / 2,
        width: width, height: height
      )
      map.setVisibleMapRect(rect, edgePadding: RouteMapDefaults.padding, animated: false)
    }
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
    let renderer = MKPolylineRenderer(polyline: line)
    renderer.strokeColor = .systemBlue
    renderer.lineWidth = RouteMapDefaults.lineWidth
    return renderer
  }
}
