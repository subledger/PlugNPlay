class SetupsController < ApplicationController
  def new
  end

  def create
    setup = params[:setup]

    begin
      setup_service.initial_setup(setup)
      redirect_to action: 'show', notice: "PnP Configured Successfully"

    rescue Exception => e
      logger.error e.backtrace

      flash[:notice] = "Error setting up app: #{e.message}"
      render action: :new
    end
  end

  def show
    @setup = setup_service.get_setup
  end

private
  def setups_params
    params.require(:setup).permit(subledger: [ :email, :identity_desc, :org_desc, :book_desc ])
  end
end
