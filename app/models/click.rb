class Click < ActiveRecord::Base

  belongs_to :clickable, :polymorphic => true
  
end