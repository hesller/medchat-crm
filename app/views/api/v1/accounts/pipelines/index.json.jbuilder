json.payload do
  json.array! @pipelines do |pipeline|
    json.id pipeline.id
    json.name pipeline.name
  end
end
