using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LocalPlayerAnimatorReference : MonoBehaviour
{

    public Animator m_Animator;

    // Start is called before the first frame update
    void Awake()
    {
        if (m_Animator == null)
        {
            m_Animator = GetComponentInChildren<Animator>();

        } 
    }

   
}
