using NSprites.Authoring;
using UnityEngine;

namespace NSprites
{
    [CreateAssetMenu(menuName = "NRendering/RenderData", fileName = "NewRenderData")]
    public class RenderDataConfig : ScriptableObject
    {
        [SerializeField] public RegisterSpriteAuthoringModule Value;
    }
}