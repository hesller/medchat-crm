json.id pipeline.id
json.name pipeline.name
json.stages pipeline.stages do |stage|
  json.partial! 'api/v1/models/pipeline_stage', stage: stage
end
