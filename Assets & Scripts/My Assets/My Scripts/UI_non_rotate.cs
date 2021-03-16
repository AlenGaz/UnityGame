using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UI_non_rotate : MonoBehaviour
{
    public Quaternion rotation;
    void Awake()
    {
        rotation = transform.rotation;
        //transform.position = new Vector3(0, 0, 0);
    }
    void LateUpdate()
    {
        if (gameObject.name == "NameCanvas")
        {
            transform.rotation = rotation;
        }
        //transform.position = new Vector3(0, 0, 0);
        if(gameObject.name == "Slider")
        {
            transform.position = transform.parent.position;
        }
    }
}