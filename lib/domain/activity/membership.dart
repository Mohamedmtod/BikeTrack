/// Evaluates a trapezoidal membership function (§7.6, D-022).
///
/// Returns:
/// - `0.0` if `v.isNaN`, `v <= a`, or (`d.isFinite && v >= d`)
/// - `(v - a) / (b - a)` if `a < v < b`
/// - `1.0` if `b <= v <= c` (or `v >= b` when `c` and `d` are `+inf`)
/// - `(d - v) / (d - c)` if `c < v < d`
double trapezoid(double v, double a, double b, double c, double d) {
  if (v.isNaN || v <= a) return 0.0;
  if (d.isFinite && v >= d) return 0.0;
  if (v < b) return (v - a) / (b - a);
  if (c.isInfinite || v <= c) return 1.0;
  return (d - v) / (d - c);
}
