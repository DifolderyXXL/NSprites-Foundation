using NSprites;
using Unity.Transforms;

[assembly: InstancedPropertyComponent(typeof(UVTilingAndOffset), "_uvTilingAndOffsetBuffer")]
[assembly: InstancedPropertyComponent(typeof(UVAtlas), "_uvAtlasBuffer")]
[assembly: InstancedPropertyComponent(typeof(LocalToWorld), "_positionBuffer")]
[assembly: InstancedPropertyComponent(typeof(Scale2D), "_heightWidthBuffer")]
[assembly: InstancedPropertyComponent(typeof(Pivot), "_pivotBuffer")]
[assembly: InstancedPropertyComponent(typeof(SortingData), "_sortingDataBuffer")]
[assembly: InstancedPropertyComponent(typeof(Flip), "_flipBuffer")]
[assembly: InstancedPropertyComponent(typeof(MaterialColor), "_colorBuffer")]