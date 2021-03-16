using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HideIfNotEditor : MonoBehaviour
{
    // Start is called before the first frame update
    void Awake()
    {
        //GetComponentInChildren<MeshRenderer>.enabled = false;
        GetComponent<MeshRenderer>().enabled = false;
    }

   
}
