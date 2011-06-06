require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'
require 'time'
require 'rho/rhotabbar'

class NoteController < Rho::RhoController
  include BrowserHelper

  #GET /Note
  def index
    @notes = Note.find(:all)
    render
  end

  # GET /Note/{1}
  def show
    @note = Note.find_note(@params['id'])
    if @note
      render :action => :show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      redirect :action => :index, :back => 'callback:'
    end
  end

  # GET /Note/new
  def new
    @note = Note.new
    render :action => :new
  end

  # GET /Note/{1}/edit
  def edit
    @note = Note.find_note(@params['id'])
    if @note
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Note/create
  def create
    @note = Note.create_new(@params['note'])
    redirect :action => :index
  end

  # POST /Note/{1}/update
  def update
    @note = Note.find_note(@params['id'])
    @note.update_attributes(@params['note']) if @note
    redirect :action => :index
  end

  # POST /Note/{1}/delete
  def delete
    @note = Note.find_note(@params['id'])
    @note.destroy if @note
    redirect :action => :index
  end
  
  def note_submit
    opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
  
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
    begin
    
    opportunity.create_note(@params['notetext'])
    finished_note_create(opportunity, @params['origin'])
    db.commit
    rescue Exception => e
      puts "Exception in update status call back requested, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  def finished_note_create(opportunity, origin)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :back => 'callback:', :id => opportunity.object, :query => {:origin => origin}
  end
  
end


