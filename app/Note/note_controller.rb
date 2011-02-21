require 'rho/rhocontroller'
require 'helpers/browser_helper'

class NoteController < Rho::RhoController
  include BrowserHelper

  #GET /Note
  def index
    @notes = Note.find(:all)
    render
  end

  # GET /Note/{1}
  def show
    @note = Note.find(@params['id'])
    if @note
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Note/new
  def new
    @note = Note.new
    render :action => :new
  end

  # GET /Note/{1}/edit
  def edit
    @note = Note.find(@params['id'])
    if @note
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Note/create
  def create
    @note = Note.create(@params['note'])
    redirect :action => :index
  end

  # POST /Note/{1}/update
  def update
    @note = Note.find(@params['id'])
    @note.update_attributes(@params['note']) if @note
    redirect :action => :index
  end

  # POST /Note/{1}/delete
  def delete
    @note = Note.find(@params['id'])
    @note.destroy if @note
    redirect :action => :index
  end
end
