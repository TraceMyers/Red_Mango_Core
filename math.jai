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

Ceil_Function :: enum {
    AWAY_FROM_ZERO; // rounds negative numbers toward negative infinity, and vice-versa
    TOWARD_POSITIVE_INFINITY; // all numbers get rounded up, away from negative infinity
}

ceil :: inline (a: float64, $To_Type := s32, $FUNC := Ceil_Function.AWAY_FROM_ZERO) -> To_Type 
#modify {
    return is_int_type(To_Type);
} {
    t_val := a.(To_Type);
    unit_part := a - t_val.(float64);
    #if FUNC == .AWAY_FROM_ZERO {
        if unit_part > 0 {
            return t_val + 1;
        } else {
            return t_val - 1;
        }
    } else { // toward positive infinity
        if unit_part > 0 {
            return t_val + 1;
        } else {
            return t_val;
        }
    }
}

Floor_Function :: enum {
    TOWARD_ZERO;
    TOWARD_NEGATIVE_INFINITY;
}

floor :: inline (a: float64, $To_Type := s32, $FUNC := Floor_Function.TOWARD_ZERO) -> To_Type 
#modify {
    return is_int_type(To_Type);
} {
    casted := a.(To_Type);
    #if FUNC == .TOWARD_ZERO {
        return casted;
    } else { // toward negative infinity
        if a < 0.0 {
            return casted - 1;
        } else {
            return casted;
        }
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

