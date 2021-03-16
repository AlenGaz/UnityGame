using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class HealthBarReactions : MonoBehaviour
{
    public Slider _slider;
    // Start is called before the first frame update
    void Awake()
    {
        GetComponent<Image>().color = Color.green;
        _slider = transform.Find("HealthBar").GetComponentInChildren<Slider>();

    }
    // Update is called once per frame
    void LateUpdate()
    {
        
        if(_slider.value < 0.5)
        {
            Debug.Log("Koskeeesh");
        }
    }
}
