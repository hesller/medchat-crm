json.payload do
  json.id @pipeline.id
  json.name @pipeline.name
  json.stages @pipeline.stages do |stage|
    json.partial! 'api/v1/models/pipeline_stage', stage: stage
    json.items @items.fetch(stage.id, []) do |item|
      json.partial! 'api/v1/models/pipeline_item', item: item
    end
  end
end
