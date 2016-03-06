class Admin::RookieAwardsController < ApplicationController
  inherit_resources

  def create
    create! do
      return redirect_to admin_rookie_awards_path
    end
  end

  def update
    update! do
      return redirect_to admin_rookie_awards_path
    end
  end

  def rookie_award_params
    params.require(:rookie_award).permit(
      :name,
      :volume,
      :money,
      :public_url,
      :submit_type,
      :deadline_date,
      :can_professional,
      :note,
    )
  end
end
