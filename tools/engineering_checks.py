"""Small deterministic engineering checks; no CAD, network, or file writes.

Nominal calculations only, not process certification. Positive clearance
means free space; negative clearance means interference. Every function is
pure (same inputs always give the same outputs) and rejects NaN/Inf and
out-of-domain inputs instead of silently returning a nonsense number.
"""
import math


def finite(value, name):
    """Coerce to float and reject NaN/Inf. Returns the finite float value."""
    value = float(value)
    if not math.isfinite(value):
        raise ValueError(f'{name} must be finite')
    return value


def fit_budget(receiver_mm, insert_mm, receiver_tol_mm=0, insert_tol_mm=0):
    """Total dimensional clearance interval, not per-side clearance.

    Divide the result by two only for a symmetric fit with justified
    concentricity; this function always reports the TOTAL budget.
    Tolerances must be nonnegative half-widths (min = nominal - both
    tolerances, max = nominal + both tolerances).
    """
    receiver, insert, receiver_tol, insert_tol = (
        finite(v, n) for v, n in zip(
            (receiver_mm, insert_mm, receiver_tol_mm, insert_tol_mm),
            ('receiver', 'insert', 'receiver_tol', 'insert_tol'),
        )
    )
    if min(receiver, insert) <= 0 or min(receiver_tol, insert_tol) < 0:
        raise ValueError('Positive sizes and nonnegative tolerances required')
    if receiver - receiver_tol <= 0 or insert - insert_tol <= 0:
        raise ValueError('Tolerance too large: receiver or insert minimum size is nonpositive')
    return dict(
        nominal_mm=receiver - insert,
        min_mm=receiver - receiver_tol - insert - insert_tol,
        max_mm=receiver + receiver_tol - insert + insert_tol,
    )


def laser_contour_size(target_finished_mm, kerf_total_mm, contour,
                        compensation_already_applied=False):
    """Centerline-cut idealization. Outer solid loses k; inner hole gains k.

    k is the full effective kerf across two boundaries, not the loss on a
    single boundary. Do not compensate twice if the CAM/controller already
    applies kerf compensation. Not valid for taper, nonuniform burn or
    material compression without a measured calibration coupon.
    """
    target = finite(target_finished_mm, 'target')
    kerf = finite(kerf_total_mm, 'kerf')
    if target <= 0 or kerf < 0 or contour not in ('outer', 'inner'):
        raise ValueError('Invalid contour inputs')
    if compensation_already_applied and kerf:
        raise ValueError('Do not compensate twice')
    result = target + (kerf if contour == 'outer' else -kerf)
    if result <= 0:
        raise ValueError('Nonpositive toolpath size')
    return result


def foam_outer_target(recess_mm, total_interference_mm):
    """Interference is total oversize, separate from kerf.

    The interference value must be a physically chosen/measured quantity
    for the foam in use; this function does not derive or bound it beyond
    requiring it to be nonnegative.
    """
    recess = finite(recess_mm, 'recess')
    interference = finite(total_interference_mm, 'interference')
    if recess <= 0 or interference < 0:
        raise ValueError('Positive recess and nonnegative interference required')
    return recess + interference


def radial_wall_cone(height_mm, base_d_mm, bore_d_mm, depth_from_base_mm):
    """Minimum radial wall left by a coaxial bore cut from a cone's base.

    The cone is a right circular cone of the given height/base diameter,
    apex above the base plane. The bore is assumed coaxial with the cone
    axis, starting at the base and going up by depth_from_base_mm, which
    must lie within [0, height_mm]. A zero or negative result means the
    bore removes the wall entirely or breaks through the side.
    """
    height, base_d, bore_d, depth = (
        finite(v, n) for v, n in zip(
            (height_mm, base_d_mm, bore_d_mm, depth_from_base_mm),
            ('height', 'base', 'bore', 'depth'),
        )
    )
    if min(height, base_d, bore_d) <= 0 or not 0 <= depth <= height:
        raise ValueError('Invalid cone/bore dimensions')
    return base_d / 2 * (1 - depth / height) - bore_d / 2


def grid_axis(span_mm, item_mm, gap_mm, margin_mm):
    """Count of equal-pitch items that fit a span with symmetric edge margins.

    A found capacity is not proof of a global optimum; it only reports one
    feasible regular layout along a single axis. Check every axis and
    every geometric margin the real layout needs, not just this one.
    """
    span, item, gap, margin = (
        finite(v, n) for v, n in zip(
            (span_mm, item_mm, gap_mm, margin_mm),
            ('span', 'item', 'gap', 'margin'),
        )
    )
    if min(span, item) <= 0 or min(gap, margin) < 0:
        raise ValueError('Invalid grid dimensions')
    count = max(0, math.floor((span - 2 * margin + gap) / (item + gap) + 1e-12))
    used = count * item + max(0, count - 1) * gap
    return dict(count=count, pitch_mm=item + gap, edge_margin_mm=(span - used) / 2)


def countersink_depth(outer_d_mm, bore_d_mm, included_angle_deg):
    """Axial depth of a conical countersink for a given included angle.

    Requires a positive bore diameter strictly smaller than the outer
    (countersink) diameter, and an included angle strictly between 0 and
    180 degrees.
    """
    outer = finite(outer_d_mm, 'outer')
    bore = finite(bore_d_mm, 'bore')
    angle = finite(included_angle_deg, 'angle')
    if bore <= 0 or outer <= bore or not 0 < angle < 180:
        raise ValueError('Invalid countersink dimensions')
    return (outer - bore) / (2 * math.tan(math.radians(angle) / 2))
