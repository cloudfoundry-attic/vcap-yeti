class RspecParallel
  def reorder_tests(case_list)
    # rails console doesn't support parallel, so arrange rails console cases dispersively
    total_number = case_list.size
    rails_console_list = []

    for i in 0..total_number-1
      t = case_list[i]["line"]
      if t.include? "rails_console"
        rails_console_list << i
      end
    end
    rails_console_number = rails_console_list.size
    if rails_console_number > 1
      mod = total_number / rails_console_number
      for i in 0..rails_console_number-1
        swap(case_list, i * mod, rails_console_list[i])
      end
    end
    case_list
  end

  def swap(a, i1, i2)
    temp = a[i1]
    a[i1] = a[i2]
    a[i2] = temp
  end
end
