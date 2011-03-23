
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
  
  # rotates the list once and returns the first item 
  def next!
    rotate!.first
  end
  
  # counter-rotates the list once and returns the first item 
  def previous!
    counter_rotate!.first
  end
  
  # rotate the list until the first item matches the given value, if that item is in the list
  def orient!(value)
    while next! != value; end if include?(value)
  end

end