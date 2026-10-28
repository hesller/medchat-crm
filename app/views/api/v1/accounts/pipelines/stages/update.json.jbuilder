json.payload do
  json.partial! 'api/v1/models/pipeline_stage', formats: [:json], stage: @stage
end
