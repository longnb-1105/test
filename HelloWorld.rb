block_table = [[1,18],[2,57.3],[3,57.3],[4,57.3],[5,57.3],[6,57.3],[7,57.3],[8,23]]
total_number_of_block = 8
separator_clearance = 0.2
separator_thickness = 2
cutter_lower_axis_no1_cutter_position = 16
cutter_thickness = 5
winding_side_clearance = 125
slip_plate_thickness = 5
winding_reel_thickness = 5
separator_side_clearance = 35

#※4 : 中央値演算用の算出方法
def calculate_median(current_block_number, block_width, total_number_of_block)
  if current_block_number <= total_number_of_block / 2
    return block_width
  elsif current_block_number.odd? && total_number_of_block / 2 == current_block_number
    return block_width / 2
  else
    return 0
  end
end

#※3 : 巻取中央値計算値の算出方法
def calculate_winding_median(block_table, total_number_of_block)
  sum_median = block_table.reduce(0) do |sum, block|
    current_block_number = block[0]
    block_width = block[1]
    median = calculate_median(current_block_number, block_width, total_number_of_block)
    sum + median
  end

  return (sum_median.round(1))
end

#※2 : 中央値範囲内の条数の算出方法
def calculate_within_median_range(block_table, current_block_number, total_number_of_block)
  winding_median = calculate_winding_median(block_table, total_number_of_block)
  sum_block_width = block_table.slice(0, current_block_number).map { |block| block[1] }.sum
  if winding_median > sum_block_width
    return 1
  else
    return 0
  end
end

#※1 : セパレータディスク&セパレータクリアランス分シフト幅の算出方法
def calculate_separator_shift_width(block_table, total_number_of_block, separator_clearance, separator_thickness)
  sum_median_within_range = block_table.reduce(0) do |sum, block|
    current_block_number = block[0]
    within_median_range = calculate_within_median_range(block_table, current_block_number, total_number_of_block)
    sum + within_median_range
  end

  separator_shift_width = (sum_median_within_range + 1) * (separator_clearance + separator_thickness) - separator_clearance / 2
  return separator_shift_width
end

#基準面から1条目までの距離
def calculate_distance_to_first_block(cutter_lower_axis_no1_cutter_position, cutter_thickness)
  distance_to_first_block = cutter_lower_axis_no1_cutter_position + cutter_thickness
  return distance_to_first_block
end

#※8 巻取軸スペーサー temp
def calculate_temp(block_table, current_block_number, total_number_of_block, separator_shift_width, separator_thickness, winding_reel_thickness, winding_side_clearance, slip_plate_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_clearance)
  if current_block_number == 0
    temp = calculate_distance_to_first_block(cutter_lower_axis_no1_cutter_position, cutter_thickness) + winding_side_clearance - separator_shift_width + separator_thickness + (block_table[0][1] - winding_reel_thickness + separator_clearance) / 2 - slip_plate_thickness
    
  else
    block_width_n = block_table[current_block_number-1][1]
    block_width_n_plus_1 = block_table[current_block_number][1]
    temp = (block_width_n + block_width_n_plus_1) / 2 - winding_reel_thickness + separator_thickness + separator_clearance - slip_plate_thickness * 2
    temp = temp < 0 ? (block_width_n + block_width_n_plus_1) / 2 - winding_reel_thickness + separator_thickness + separator_clearance - slip_plate_thickness : temp
  end

  return temp
end

#※7 小数点以下
def calculate_decimal_part(value)
  # Làm tròn số và chỉ lấy 2 số sau dấu thập phân
  rounded_value = value.round(2)

  # Tính phần thập phân
  decimal_part = (rounded_value - rounded_value.to_i).round(2)

  # Trả về phần thập phân đã làm tròn
  decimal_part
end

#※6 計, ※5 繰り上げ, 最終値_巻取軸スペーサー
def calculate_kei_kurikami_makitoriSpacer(block_table, separator_shift_width, separator_thickness, winding_reel_thickness, winding_side_clearance, slip_plate_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_clearance)
  kei_total = 0
  kurikami_total = 0

  (0..block_table.length - 1).each do |current_block_number|
    temp = calculate_temp(block_table, current_block_number, block_table.length - 1, separator_shift_width, separator_thickness, winding_reel_thickness, winding_side_clearance, slip_plate_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_clearance)

    decimal_part = calculate_decimal_part(temp)

    if current_block_number == 0
      kei = decimal_part + calculate_decimal_part(calculate_temp(block_table, current_block_number + 1, block_table.length - 1, separator_shift_width, separator_thickness, winding_reel_thickness, winding_side_clearance, slip_plate_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_clearance))
    else
      kei = kei_total + decimal_part - kurikami_total
    end

    if kei >= 0.45
      kurikami = 1
    else
      kurikami = 0
    end

    kei_total += decimal_part
    kurikami_total += kurikami

    # Làm tròn và chỉ lấy 2 số sau dấu thập phân
    temp_rounded = temp.round(2)
    decimal_part_rounded = decimal_part.round(2)
    kei_rounded = kei.round(2)

    puts "巻取軸スペーサー temp của block #{current_block_number} = #{temp_rounded}, 小数点以下 của block #{current_block_number} = #{decimal_part_rounded}, 計 của block #{current_block_number} = #{kei_rounded}, 繰り上げ của block #{current_block_number} = #{kurikami}"

    # Tính giá trị 巻取軸スペーサー_final
    巻取軸スペーサー_final = temp.to_i + kurikami
    puts "巻取軸スペーサー_final của block #{current_block_number} = #{巻取軸スペーサー_final}"
  end
end

#In ra xem thế lào lào 
separator_shift_width = calculate_separator_shift_width(block_table, total_number_of_block, separator_clearance, separator_thickness)

calculate_kei_kurikami_makitoriSpacer(block_table, separator_shift_width, separator_thickness, winding_reel_thickness, winding_side_clearance, slip_plate_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_clearance)

#セパレータ軸スペーサー /Hàm tính spacer trục tách 
def calculate_separator_axis_spacer(block_table, separator_clearance, separator_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_side_clearance)
  separator_axis_spacer = []
  
  # セパレータ軸スペーサー của block 0
  distance_to_first_block = calculate_distance_to_first_block(cutter_lower_axis_no1_cutter_position, cutter_thickness)  # Giả sử từ block 0 đến 基準面 là 0
  separator_shift_width = calculate_separator_shift_width(block_table, block_table.length, separator_clearance, separator_thickness)
  separator_axis_spacer_block = distance_to_first_block - separator_shift_width + separator_side_clearance
  separator_axis_spacer << separator_axis_spacer_block
  
  # セパレータ軸スペーサー của block 1~hiện tại
  block_table.each_with_index do |block, index|
    block_width = block[1]
    separator_axis_spacer_block = block_width + separator_clearance
    separator_axis_spacer << separator_axis_spacer_block
  end

  separator_axis_spacer
end

separator_axis_spacer_values = calculate_separator_axis_spacer(block_table, separator_clearance, separator_thickness, cutter_lower_axis_no1_cutter_position, cutter_thickness, separator_side_clearance)
separator_axis_spacer_values.each_with_index do |value, index|
  puts "セパレータ軸スペーサー của block #{index} = #{value.round(2)}"
end
