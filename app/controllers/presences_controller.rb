require 'csv'

class PresencesController < ApplicationController
  before_action :set_presence, only: [:show, :edit, :update, :destroy]
  http_basic_authenticate_with name: "ahmldm", password: "fnq6aMuQZLR4Rgm6", except: [:new, :create, :confirmation]

  # GET /presences
  # GET /presences.json
  def index
    @presences = Presence.page(params[:page]).order("activity_date DESC").order("REPLACE(start_time, ':', '')::int DESC")
    days = Presence.all.map {|i| i.created_at.to_date }

    @days = days.uniq.sort
  end

  # GET /presences/1
  # GET /presences/1.json
  def show
  end

  # GET /presences/new
  def new
    @presence = Presence.new

    time_zoned = Time.now.round_off(30.minutes).in_time_zone("America/New_York")
    hour = time_zoned.hour
    minutes = '%02d' % time_zoned.min
    end_hour = hour + 1
    end_hour = 1 if end_hour > 24
  end_hour = 7
    @presence.start_time = "#{hour}:#{minutes}"
    @presence.end_time = "#{end_hour}:#{minutes}"

    @presence_times = presence_times
  end

  # GET /presences/1/edit
  def edit
    @presence_times = presence_times
  end

  # POST /presences
  # POST /presences.json
  def create
    @presence = Presence.new(presence_params)
    @presence.activity_date = Date.today
    respond_to do |format|
      if @presence.save
        format.html { redirect_to confirmation_presences_url, notice: 'Presence was successfully created.' }
        format.json { render :show, status: :created, location: @presence }
      else
        format.html { render :new }
        format.json { render json: @presence.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /presences/1
  # PATCH/PUT /presences/1.json
  def update
    respond_to do |format|
      if @presence.update(presence_params)
        format.html { redirect_to @presence, notice: 'Presence was successfully updated.' }
        format.json { render :show, status: :ok, location: @presence }
      else
        format.html { render :edit }
        format.json { render json: @presence.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /presences/1
  # DELETE /presences/1.json
  def destroy
    @presence.destroy
    respond_to do |format|
      format.html { redirect_to presences_url, notice: 'Presence was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def confirmation
  end

  def export
    date = params[:selectdate]
    arena = params[:arena]
    start_date = DateTime.parse(date).beginning_of_day
    end_date = DateTime.parse(date).end_of_day
    presences = Presence.where(:created_at => start_date..end_date, :arena => arena).order("REPLACE(start_time, ':', '')::int ASC")
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Date", "Heure de debut", "Heure de fin", "Nom joueur/benevole", "Accompagnateur", "Telephone", "Arena", "Question 1", "Question 2", "Question 3", "Question 4"]

      presences.each do |p|
        csv << [p.activity_date, p.start_time, p.end_time, p.name, p.attendant, p.phone_number, p.arena, p.question1, p.question2, p.question3, p.question4]
      end
    end

    send_data csv_data, filename: "presence-#{arena}-#{date}.csv"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_presence
      @presence = Presence.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def presence_params
      params.require(:presence).permit(:name, :attendant, :phone_number, :arena, :question1, :question2, :question3, :question4, :start_time, :end_time)
    end

    def presence_times
      p_times = []
      (1..24).each do |hour|
        p_times << "#{hour}:00"
        p_times << "#{hour}:30"
      end
      p_times
    end
end
