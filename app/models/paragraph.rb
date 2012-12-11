class Paragraph < ActiveRecord::Base
  
  belongs_to :paragraphable, :polymorphic => true
  
end
