json.payload do
  json.array! @health_plans do |health_plan|
    json.partial! 'api/v1/accounts/health_plans/health_plan', health_plan: health_plan
  end
end
