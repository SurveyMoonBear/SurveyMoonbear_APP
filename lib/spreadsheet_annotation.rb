# frozen_string_literal: true

# get spreadsheet value range A1:A5
module SpreadsheetAnnotation
  # C3:C141 shift(2) ;run 141-3+1 times;
  def transform_anotation(range)
    alphabet_table = { 'A' => 0, 'B' => 1, 'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7, 'I' => 8, 'J' => 9,
                       'K' => 10, 'L' => 11, 'M' => 12, 'N' => 13, 'O' => 14, 'P' => 15, 'Q' => 16, 'R' => 17, 'S' => 18, 'T' => 19,
                       'U' => 20, 'V' => 21, 'W' => 22, 'X' => 23, 'Y' => 24, 'Z' => 25, 'AA' => 26, 'AB' => 27, 'AC' => 28, 'AD' => 29,
                       'AE' => 30, 'AF' => 31, 'AG' => 32, 'AH' => 33, 'AI' => 34, 'AJ' => 35, 'AK' => 36, 'AL' => 37, 'AM' => 38, 'AN' => 39,
                       'AO' => 40, 'AP' => 41, 'AQ' => 42, 'AR' => 43, 'AS' => 44, 'AT' => 45, 'AU' => 46, 'AV' => 47, 'AW' => 48, 'AX' => 49,
                       'AY' => 50, 'AZ' => 51 }
    range = range.split(':')
    start_row = range[0].split(/([A-Z]+)/)
    start_row.shift
    end_row = range[1].split(/([A-Z]+)/)
    end_row.shift
    column_times = alphabet_table[end_row[0]] - alphabet_table[start_row[0]] + 1
    row_times = end_row[1].to_i - start_row[1].to_i + 1
    { 'shift_num': start_row[1].to_i - 1,
      'column': alphabet_table[start_row[0]],
      'column_times': column_times,
      'row_times': row_times }
  end

  # case_range = {shift_num:...,column:...,column_times:...,row_times:...}
  # all_data is spreadsheet data
  def get_range_val(all_data, case_range)
    new_val = []
    data = all_data.drop(case_range[:shift_num])
    data.each_with_index do |row_value, idx|
      break if idx == case_range[:row_times]

      new_val.append(row_value[case_range[:column]])
    end
    new_val
  end
end
