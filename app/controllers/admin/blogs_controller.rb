class Admin::BlogsController < ApplicationController
  layout 'admin'
  active_scaffold :blogs
end