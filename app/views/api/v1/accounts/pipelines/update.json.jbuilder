json.payload do
  json.partial! 'api/v1/models/pipeline', pipeline: @pipeline
end
