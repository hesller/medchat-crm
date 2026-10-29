json.payload do
  json.array! @professionals do |professional|
    json.partial! 'api/v1/accounts/professionals/professional', professional: professional
  end
end
