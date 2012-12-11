class Admin::PagesController < ApplicationController
  layout 'admin'
  active_scaffold :pages
  
end