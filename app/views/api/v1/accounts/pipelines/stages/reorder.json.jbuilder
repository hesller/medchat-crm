json.payload do
  json.array! @stages do |stage|
    json.partial! 'api/v1/models/pipeline_stage', formats: [:json], stage: stage
  end
end
