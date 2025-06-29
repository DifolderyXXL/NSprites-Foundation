using Unity.Entities;
using UnityEngine;

namespace NSprites
{
    public struct MaterialColor : IComponentData
    {
        public Color Value;
    }
}