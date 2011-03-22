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

end
