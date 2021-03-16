using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DestroyAfterTime : MonoBehaviour
{
    private  Vector3 offset = new Vector3(0f,1f,0);
    public float destroyAfterTimer = 15f;
    void Start()
    {
        transform.position += offset;
        if (destroyAfterTimer > 10f) {
            destroyAfterTimer = destroyAfterTimer + Random.Range(-1, 4);
        }
        
        destroyAfterTime();
    }

    private void destroyAfterTime()
    {
        Destroy(this.gameObject, destroyAfterTimer);
    }
    
}
