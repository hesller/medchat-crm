json.payload do
  json.id @pipeline.id
  json.name @pipeline.name
  json.position @pipeline.position
  json.stages @stages do |stage|
    json.partial! 'api/v1/models/pipeline_stage', formats: [:json], stage: stage
    json.cards stage.cards do |card|
      json.partial! 'api/v1/models/pipeline_card', formats: [:json], card: card
    end
  end
end
