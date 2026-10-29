class AddEncaixeDailyLimitToProfessionals < ActiveRecord::Migration[7.2]
  def change
    add_column :professionals, :encaixe_daily_limit, :integer
    add_column :professionals, :encaixe_calendar_id, :string
  end
end
