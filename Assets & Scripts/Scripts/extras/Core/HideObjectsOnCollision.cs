using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HideObjectsOnCollision : MonoBehaviour
{

    private void Start()
    {
        gameObject.layer = LayerMask.NameToLayer("Ignore Raycast");
    }

    void OnTriggerEnter(Collider collision)
    {
        GameObject other = collision.gameObject;

        try
        {
            other.GetComponentInChildren<MeshRenderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.ShadowsOnly;
        }
        catch (System.Exception) { }
            other.layer = LayerMask.NameToLayer("Ignore Raycast");      
            }

    void OnTriggerExit(Collider collision)
    {
        GameObject other = collision.gameObject;
        other.GetComponentInChildren<MeshRenderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
        other.layer = LayerMask.NameToLayer("Default");   //////////////

    }

}

   

