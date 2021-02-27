
## Storage Component

### Registry Database

|COMPONENT ID|ROOT COMPONENT ID|FRIENDLY NAME|ABSTRACT|
|:----------:|:---------------:|:-----------:|:------:|
| componentId0 | null | friendlyName0 | true |
| componentId1 | rootId0 | friendlyName1 | false |

### Meta Registry Database

|REGISTRY ID|CLOUD PROVIDER ID|FRIENDLY NAME|IMPLEMENTATION|
|:---------:|:---------------:|:-----------:|:------------:|
| registryId0 | cloudProviderId0 | friendlyName0 | implementation0 |

#### Programs

```
Program CreateRegistryDatabaseSchema
begin
    return RegistryDatabaseSchema([
        "ComponentId",
        "CloudProviderId",
        "FriendlyName"
    ])
end

Program CreateRegistryDatabase
Inputs
  cloudProvider: CloudProvider,
  registryDatabaseSchema: RegistryDatabaseSchema,
  modality: RegistryDatabaseImplementationModality
begin
  implementation = cloudProvider.registryDatabase.implementation(modality)
  implementation.setSchema(registryDatabaseSchema)

  cloudProvider.registryDatabase.create()
  cloudProvider.registryDatabase.createLogStream()
  cloudProvider.registryDatabase.logStream.log(Registry Database information)

  return cloudProvider.registryDatabase.logStream
end

Program CleanUpRegistryDatabase
Inputs
  cloudProvider: CloudProvider
begin
  

end

Program RegisterComponent
Inputs
  cloudProvider: CloudProvider

begin

end
```