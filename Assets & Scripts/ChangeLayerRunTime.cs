using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeLayerRunTime : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        gameObject.layer = LayerMask.NameToLayer("Ignore Raycast");

        Debug.Log("Layer 2 is:" + LayerMask.LayerToName(gameObject.layer));
        

    }

}
