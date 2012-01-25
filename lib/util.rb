module Util
  def self.get_classes
    classes = []
    ObjectSpace.each_object(Class) do |c|
      classes << c
    end
    classes
  end
end
