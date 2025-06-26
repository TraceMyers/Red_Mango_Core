QUATERNION_IDENTITY :: Quaternion.{0,0,0,1};
VectorTypes :: Type.[Vector2, Vector3, Vector4, Quaternion];  // Used for type restriction in normalize().
VectorAndFloatTypes :: Type.[Vector2, Vector3, Vector4, Quaternion, float32, float64];  // Used for type restriction in normalize().

div_ceil :: inline (a: $Int_Type, b: Int_Type) -> Int_Type 
#modify {
    return is_int_type(Int_Type);
} {
    assert(a >= 0 && b > 0);
    return ((a - 1) / b) + 1;
}

ceil_to_multiple :: inline (a: $Int_Type, b: Int_Type) -> Int_Type
#modify {
    return is_int_type(Int_Type);
} {
    assert(a >= 0 && b > 0);
    return div_ceil(a, b) * b;
}

floor_to_multiple :: inline (a: $Int_Type, b: Int_Type) -> Int_Type
#modify {
    return is_int_type(Int_Type);
} {
    assert(a >= 0 && b > 0);
    return (a / b) * b;
}

round :: (a: float64, $Int_Type := s32) -> Int_Type 
#modify {
    return is_int_type(Int_Type);
} {
    if a < min_value(Int_Type).(float64) {
        return min_value(Int_Type);
    }
    rounded_toward_zero := a.(Int_Type);
    if a > 0 && rounded_toward_zero < 0 { // overflow on cast
        return max_value(Int_Type);
    }
    diff := a - cast(float64)rounded_toward_zero;
    if diff > 0.5 {
        return rounded_toward_zero + 1;
    } else if diff < -0.5 {
        return rounded_toward_zero - 1;
    } else {
        return rounded_toward_zero;
    }
}

// cast between int and normalized or non-normalized floats with optional rounding on float->int
alter_cast :: inline (number: $In_Type, $Out_Type: Type, $NORMALIZED_FLOAT := false, $ROUND_TO_INT := true) -> Out_Type
#modify {
    float_to_int := is_float_type(In_Type) && is_int_type(Out_Type);
    int_to_float := is_int_type(In_Type) && is_float_type(Out_Type);
    return float_to_int || int_to_float;
} {
    MIN_IN :: #run min_value(In_Type);
    MAX_IN :: #run max_value(In_Type);
    IN_DIFF :: MAX_IN - MIN_IN;
    MIN_OUT :: #run min_value(Out_Type);
    MAX_OUT :: #run max_value(Out_Type);
    OUT_DIFF :: MAX_OUT - MIN_OUT;
    IN_IS_FLOAT :: #run type_info(In_Type).type == .FLOAT;
    OUT_IS_FLOAT :: #run type_info(Out_Type).type == .FLOAT;
    FLOAT_TO_INT :: IN_IS_FLOAT && !OUT_IS_FLOAT;
    INT_TO_FLOAT :: !IN_IS_FLOAT && OUT_IS_FLOAT;

    #if NORMALIZED_FLOAT {
        #if FLOAT_TO_INT {
            #if ROUND_TO_INT {
                return round(MIN_OUT.(float64) + (MAX_OUT.(float64) - MIN_OUT.(float64)) * xx number, Out_Type);
            } else {
                return xx (MIN_OUT.(float64) + (MAX_OUT.(float64) - MIN_OUT.(float64)) * xx number);
            }
        } else #if INT_TO_FLOAT {
            return xx clamp((number.(float64) - MIN_IN.(float64)) / IN_DIFF.(float64), 0.0, 1.0);
        }
    } else {
        if number < MIN_OUT {
            return MIN_OUT;
        } else if number > MAX_OUT {
            return MAX_OUT;
        } else {
            #if FLOAT_TO_INT && ROUND_TO_INT {
                return round(number, Out_Type);
            } 
            return xx number;
        }
    }
    return xx 0;
}

respace :: (v: float, in_range: Vector2, out_range: Vector2) -> float {
    norm_val: float = ---;
    if in_range.y > in_range.x {
        in_range_width := in_range.y - in_range.x;
        norm_val = (clamp(v, in_range.x, in_range.y) - in_range.x) / in_range_width;
    } else {
        in_range_width := in_range.x - in_range.y;
        norm_val = 1.0 - (clamp(v, in_range.y, in_range.x) - in_range.y) / in_range_width;
    }
    out_range_width := out_range.y - out_range.x;
    return out_range.x + out_range_width * norm_val;
}

is_normalized :: (v: $Vec_Type, tolerance := 0.0001) -> bool {
    return abs(length_squared(v) - 1.0) < tolerance;
}

increment_wrap :: inline (val: $T, min: T, max: T) -> T {
    val += 1;
    if val > max {
        val = min;
    }
    return val;
}

decrement_wrap :: inline (val: $T, min: T, max: T) -> T {
    val -= 1;
    if val < min {
        val = max;
    }
    return val;
}

add_wrap :: (val: $T, add_amt: T, min: T, max: T) -> T 
#modify {
    return is_int_type(T);
} {
    assert(val >= min && val <= max && max >= min);
    sum := val + add_amt;
    min_max_diff := (max - min) + 1;
    if sum > max {
        sum_max_diff := sum - (max + 1); // adding one makes the rest simpler
        remainder := sum_max_diff % min_max_diff;
        return min + remainder;
    } else if sum < min {
        min_sum_diff := (min - 1) - sum;
        remainder := min_sum_diff % min_max_diff;
        return max - remainder;
    } else {
        return sum;
    }
}

is_power_of_two :: inline (val: s64) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

is_power_of_two :: inline (val: u64) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

do_ranges_overlap :: inline (x1: $T, x2: T, y1: T, y2: T) -> bool {
    return y2 >= x1 && y1 <= x2;
}

make_quat :: (forward: Vector3, up: Vector3) -> Quaternion {
    right := cross(forward, up);
    assert(is_normalized(forward,0.001));
    assert(is_normalized(right,0.001));
    assert(is_normalized(up,0.001));
    rot_matrix := Matrix3.{
        right.x, forward.x, up.x,
        right.y, forward.y, up.y,
        right.z, forward.z, up.z,
    };
    return get_rotation(rot_matrix);
}

set_orientation :: (out_orientation: *Quaternion, forward: Vector3, up: Vector3) {
    out_orientation.* = make_quat(forward, up);
}

rotate :: (in_out_orientation: *Quaternion, axis: Vector3, angle: float32) {
    assert(is_normalized(axis));
    ht := angle * 0.5;
    rot_quat := Quaternion.{xyz=axis*sin(ht), w=cos(ht)};
    in_out_orientation.* = rot_quat * in_out_orientation.*;
}

rotate :: inline (v: Vector3, axis: Vector3, angle: float32) -> Vector3 {
    assert(is_normalized(axis));
    ht := angle * 0.5;
    rot_quat := Quaternion.{xyz=axis*sin(ht), w=cos(ht)};
    return rotate(v, rot_quat);
}

right_direction :: inline (q: *Quaternion) -> Vector3 {
    return rotate(MANGO_RIGHT, q);
}

right_direction_xy :: inline (q: *Quaternion) -> Vector3 {
    right_3d := right_direction(q);
    right_3d.z = 0;
    return normalize(right_3d);
}

fore_direction_xy :: inline (q: *Quaternion) -> Vector3 {
    fore_3d := fore_direction(q);
    fore_3d.z = 0;
    return normalize(fore_3d);
}

up_direction :: inline (q: *Quaternion) -> Vector3 {
    return rotate(MANGO_UP, q);
}

fore_direction :: inline (q: *Quaternion) -> Vector3 {
    return rotate(MANGO_FORE, q);
}

distance_squared :: inline (q1: Quaternion, q2: Quaternion) -> float {
    diff := Vector4.{
        q1.x - q2.x,
        q1.y - q2.y,
        q1.z - q2.z,
        q1.w - q2.w,
    };
    return length_squared(diff);
}

distance :: inline (q1: Quaternion, q2: Quaternion) -> float {
    diff := Vector4.{
        q1.x - q2.x,
        q1.y - q2.y,
        q1.z - q2.z,
        q1.w - q2.w,
    };
    return length(diff);
}

interp_rotate :: (origin: Quaternion, target: Quaternion, norm: float32) -> Quaternion {
    assert(norm >= 0.0 && norm <= 1.0);
    // small distances can be lerped without being able to tell the difference
    dp := dot(origin, target);
    use_target := ifx dp < 0 then -target else target;
    rot_dist_sq := distance_squared(origin, use_target);
    if rot_dist_sq <= 0.0001 {
        return target;
    }
    if rot_dist_sq < 0.15 {
         return lerp(origin, use_target, norm);
    } else return slerp(origin, use_target, norm);
}

interp_rotate :: (origin: Quaternion, target: Quaternion, speed: float32, delta_time: float32) -> Quaternion {
    rot_dist := speed * delta_time;
    cos_ht := abs(dot(origin, target));
    // todo: prob don' need to do acos here and in slerp
    t := 2.0 * acos(cos_ht);
    if abs(rot_dist) >= t {
        return target;
    } 
    return interp_rotate(origin, target, rot_dist / t);
}

// todo do these work???
// ------------------
smoothstep :: (a: float, b: float, x: float) -> float {
    denom_1 := (b - a) * (b - a);
    denom_2 := denom_1 * (b - a);
    numerator_1 := (x - a) * (x - a);
    numerator_2 := numerator_1 * (x - a);
    return 3.0 * (numerator_1 / denom_1) - 2.0 * (numerator_2 / denom_2);
}

smoothstep :: (a: $T/VectorTypes, b: T, x: float32) -> T {
    out_vec: T = ---;
    out_vec.x = smoothstep(a.x, b.x, x);
    out_vec.y = smoothstep(a.y, b.y, x);
    #if out_vec.component.count >= 3 {
        out_vec.z = smoothstep(a.z, b.z, x);
    }
    #if out_vec.component.count == 4 {
        out_vec.w = smoothstep(a.w, b.w, x);
    }
    return out_vec;
}
// ------------------

smoothstep :: (x: float) -> float {
    return 3.0 * x * x - 2.0 * x * x * x;
}

exponential_interp :: (a: $T/VectorAndFloatTypes, b: T, speed: float32, delta_time: float32) -> T {
    move_factor := min(speed * delta_time, 1.0);
    return a + (b - a) * move_factor;
}
