using System;
using NSprites.Authoring;
using Unity.Entities;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;

namespace NSprites
{
    /// <summary>
    /// Adds basic render components such as <see cref="UVAtlas"/>, <see cref="UVTilingAndOffset"/>, <see cref="Scale2D"/>, <see cref="Pivot"/>.
    /// Optionally adds sorting components, removes built-in 3D transforms and adds 2D transforms.
    /// </summary>
    public class SpriteRendererAuthoring : MonoBehaviour
    {
        private class Baker : Baker<SpriteRendererAuthoring>
        {
            public override void Bake(SpriteRendererAuthoring authoring)
            {
                if (!authoring.IsValid)
                    return;

                DependsOn(authoring);

                authoring.RenderDataConfig.Value.Bake(this, authoring.OverrideTextureFromSprite ? authoring.Sprite.texture : null);
                var uvAtlas = (float4)NSpritesUtils.GetTextureST(authoring.Sprite);
                authoring.RenderSettings.Bake(this, authoring, authoring.Sprite.GetNativeSize(uvAtlas.xy), uvAtlas, authoring.Color);
                authoring.Sorting.Bake(this);
            }
        }

        public void Reset()
        {
            string[] regularRenderGuids = AssetDatabase.FindAssets("Regular Render");

            foreach (var path in regularRenderGuids)
            {
                string regularRenderPath = AssetDatabase.GUIDToAssetPath(path);
                
                string[] configGuids = AssetDatabase.FindAssets("t:RenderDataConfig", new[] { regularRenderPath });
                if (configGuids.Length > 0)
                {
                    string configPath = AssetDatabase.GUIDToAssetPath(configGuids[0]);
                    RenderDataConfig = AssetDatabase.LoadAssetAtPath<RenderDataConfig>(configPath);
                    return;
                }
            }
        }

        [SerializeField] public Sprite Sprite;
        [SerializeField] public Color Color = Color.white;
        [SerializeField] public RenderDataConfig RenderDataConfig;
        [SerializeField] public bool OverrideTextureFromSprite = true;
        
        [SerializeField] public SpriteSettingsAuthoringModule RenderSettings;
        [SerializeField] public SortingAuthoringModule Sorting;
        
        private bool IsValid
        {
            get
            {
                if (RenderDataConfig is null)
                {
                    Debug.LogWarning(new NSpritesException("RenderDataConfig is null"), gameObject);
                    return false;
                }

                if (!RenderDataConfig.Value.IsValid(out var message))
                {
                    Debug.LogWarning(new NSpritesException(message), gameObject);
                    return false;
                }
                
                // Settings just have struct values and there is nothing to validate

                if (Sprite == null)
                {
                    Debug.LogWarning(new NSpritesException($"{GetType().Name}: {nameof(Sprite)} is null"), gameObject);
                    return false;
                }

                return true;
            }
        }
    }
}
