json.id pipeline.id
json.name pipeline.name
json.position pipeline.position
json.stages pipeline.stages do |stage|
  json.partial! 'api/v1/models/pipeline_stage', formats: [:json], stage: stage
end
