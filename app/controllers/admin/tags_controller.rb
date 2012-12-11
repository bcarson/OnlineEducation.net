class Admin::TagsController < ApplicationController
  layout 'admin'
  active_scaffold :tags
end