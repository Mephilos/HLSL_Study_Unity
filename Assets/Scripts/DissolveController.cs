using UnityEngine;

public class DissolveController : MonoBehaviour
{
    public Material dissolveMaterial;
    public float dissolveSpeed = 0.5f;
    private float dissolveAmount = 0f;
    private bool isDissolving = true;


    void Update()
    {
        if (isDissolving)
        {
            dissolveAmount += Time.deltaTime * dissolveSpeed;
            if (dissolveAmount >= 1f)
            {
                dissolveAmount = 1f;
                isDissolving = false;
            }
        }
        else
        {
            dissolveAmount -= Time.deltaTime * dissolveSpeed;
            
            if (dissolveAmount <= 0f)
            {
                dissolveAmount = 0f;
                isDissolving = true;
            }
        }
    
        dissolveMaterial.SetFloat("_DissolveAmount", dissolveAmount);
    }
}
