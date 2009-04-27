require File.join(File.dirname(__FILE__),'/../../init')

class ModelWithUuid < ActiveRecord::Base
  
  use_uuid :schema_less_attrs => [:likes, :irrelevants, :topics, :author_name, :author_href,
                                       :rank, :content, :image_1]
                                       
  # just to show that init may be overriden without disturbing use_uuid                                                                          
  def initialize(attrs = {}, &block) 
    super
    
  end
  
  
end
