"""Offline checks for tools/engineering_checks.py; no CAD, network, or file writes.
Dimensions below are synthetic examples chosen to exercise the math and its
domain guards, not a certified part specification.
"""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import engineering_checks as checks


class FiniteTests(unittest.TestCase):
    def test_accepts_finite_values(self):
        self.assertEqual(checks.finite(3, 'x'), 3.0)
        self.assertEqual(checks.finite('2.5', 'x'), 2.5)

    def test_rejects_nan_and_infinite(self):
        for bad in (float('nan'), float('inf'), float('-inf')):
            with self.assertRaises(ValueError):
                checks.finite(bad, 'x')


class FitBudgetTests(unittest.TestCase):
    def test_nominal_min_max_without_tolerance(self):
        result = checks.fit_budget(10, 8)
        self.assertEqual(result, dict(nominal_mm=2, min_mm=2, max_mm=2))

    def test_nominal_min_max_with_tolerance(self):
        result = checks.fit_budget(10, 8, receiver_tol_mm=0.05, insert_tol_mm=0.02)
        self.assertAlmostEqual(result['nominal_mm'], 2.0)
        self.assertAlmostEqual(result['min_mm'], 1.93)
        self.assertAlmostEqual(result['max_mm'], 2.07)

    def test_rejects_nonpositive_sizes(self):
        with self.assertRaises(ValueError):
            checks.fit_budget(0, 8)
        with self.assertRaises(ValueError):
            checks.fit_budget(10, -1)

    def test_rejects_negative_tolerance(self):
        with self.assertRaises(ValueError):
            checks.fit_budget(10, 8, receiver_tol_mm=-0.01)

    def test_rejects_tolerance_collapsing_receiver_or_insert(self):
        with self.assertRaises(ValueError):
            checks.fit_budget(10, 8, receiver_tol_mm=10)
        with self.assertRaises(ValueError):
            checks.fit_budget(10, 8, insert_tol_mm=8)

    def test_rejects_nan(self):
        with self.assertRaises(ValueError):
            checks.fit_budget(float('nan'), 8)


class LaserContourSizeTests(unittest.TestCase):
    def test_outer_grows_by_kerf(self):
        self.assertAlmostEqual(checks.laser_contour_size(100, 0.2, 'outer'), 100.2)

    def test_inner_shrinks_by_kerf(self):
        self.assertAlmostEqual(checks.laser_contour_size(100, 0.2, 'inner'), 99.8)

    def test_zero_kerf_is_a_no_op(self):
        self.assertAlmostEqual(checks.laser_contour_size(50, 0, 'outer'), 50)
        self.assertAlmostEqual(checks.laser_contour_size(50, 0, 'inner'), 50)

    def test_rejects_negative_kerf(self):
        with self.assertRaises(ValueError):
            checks.laser_contour_size(50, -0.1, 'outer')

    def test_rejects_unknown_contour(self):
        with self.assertRaises(ValueError):
            checks.laser_contour_size(50, 0.1, 'side')

    def test_rejects_double_compensation(self):
        with self.assertRaises(ValueError):
            checks.laser_contour_size(50, 0.1, 'outer', compensation_already_applied=True)

    def test_allows_flag_when_kerf_is_zero(self):
        self.assertAlmostEqual(
            checks.laser_contour_size(50, 0, 'outer', compensation_already_applied=True), 50,
        )

    def test_rejects_nonpositive_result(self):
        with self.assertRaises(ValueError):
            checks.laser_contour_size(0.1, 0.2, 'inner')


class FoamOuterTargetTests(unittest.TestCase):
    def test_adds_total_interference(self):
        self.assertAlmostEqual(checks.foam_outer_target(20, 0.3), 20.3)

    def test_rejects_nonpositive_recess(self):
        with self.assertRaises(ValueError):
            checks.foam_outer_target(0, 0.1)

    def test_rejects_negative_interference(self):
        with self.assertRaises(ValueError):
            checks.foam_outer_target(20, -0.1)


class RadialWallConeTests(unittest.TestCase):
    """Reference values match ConeValidation.bas / ConeBore9.bas: a synthetic
    H30 mm x D10 mm cone with a D5 mm coaxial bore starting at the base."""

    def test_bore_depth_15_leaves_zero_wall(self):
        self.assertAlmostEqual(checks.radial_wall_cone(30, 10, 5, 15), 0.0, places=6)

    def test_bore_depth_9_leaves_one_mm_wall(self):
        self.assertAlmostEqual(checks.radial_wall_cone(30, 10, 5, 9), 1.0, places=6)

    def test_bore_depth_16_is_negative_breakthrough(self):
        self.assertLess(checks.radial_wall_cone(30, 10, 5, 16), 0.0)

    def test_rejects_depth_outside_height(self):
        with self.assertRaises(ValueError):
            checks.radial_wall_cone(30, 10, 5, -1)
        with self.assertRaises(ValueError):
            checks.radial_wall_cone(30, 10, 5, 31)

    def test_rejects_nonpositive_dimensions(self):
        with self.assertRaises(ValueError):
            checks.radial_wall_cone(0, 10, 5, 1)
        with self.assertRaises(ValueError):
            checks.radial_wall_cone(30, -10, 5, 1)

    def test_rejects_nan(self):
        with self.assertRaises(ValueError):
            checks.radial_wall_cone(30, 10, 5, float('nan'))


class GridAxisTests(unittest.TestCase):
    def test_typical_layout(self):
        result = checks.grid_axis(span_mm=100, item_mm=10, gap_mm=2, margin_mm=5)
        self.assertEqual(result['count'], 7)
        self.assertAlmostEqual(result['pitch_mm'], 12)
        self.assertAlmostEqual(result['edge_margin_mm'], 9.0)

    def test_exact_fit_without_gap_or_margin(self):
        result = checks.grid_axis(span_mm=50, item_mm=10, gap_mm=0, margin_mm=0)
        self.assertEqual(result['count'], 5)
        self.assertAlmostEqual(result['edge_margin_mm'], 0.0)

    def test_rejects_negative_gap_or_margin(self):
        with self.assertRaises(ValueError):
            checks.grid_axis(100, 10, -1, 0)
        with self.assertRaises(ValueError):
            checks.grid_axis(100, 10, 0, -1)

    def test_rejects_nonpositive_span_or_item(self):
        with self.assertRaises(ValueError):
            checks.grid_axis(0, 10, 1, 1)
        with self.assertRaises(ValueError):
            checks.grid_axis(100, 0, 1, 1)


class CountersinkDepthTests(unittest.TestCase):
    def test_typical_countersink(self):
        self.assertAlmostEqual(checks.countersink_depth(10, 5, 90), 2.5)

    def test_rejects_bore_at_or_above_outer(self):
        with self.assertRaises(ValueError):
            checks.countersink_depth(5, 5, 90)
        with self.assertRaises(ValueError):
            checks.countersink_depth(4, 5, 90)

    def test_rejects_angle_outside_open_interval(self):
        with self.assertRaises(ValueError):
            checks.countersink_depth(10, 5, 0)
        with self.assertRaises(ValueError):
            checks.countersink_depth(10, 5, 180)

    def test_rejects_nonpositive_bore(self):
        with self.assertRaises(ValueError):
            checks.countersink_depth(10, 0, 90)


if __name__ == '__main__':
    unittest.main()
