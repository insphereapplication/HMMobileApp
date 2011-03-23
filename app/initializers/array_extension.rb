
# turns an Array into a rotating list. 
class Array
  
  def rotate! 
    a = reverse!.pop
    replace reverse.push a
  end
  
  def counter_rotate!
     a = pop
     replace reverse.push(a).reverse
  end
  
  def next!
    rotate!.first
  end
  
  def previous!
    counter_rotate!.first
  end
  
  # rotate the list until the first item matches the value
  def orient!(value)
    while next! != value; end if include?(value)
  end

end