json.payload do
  json.partial! 'api/v1/models/pipeline_card', formats: [:json], card: @card
end
