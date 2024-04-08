using System;
using UnityEngine;

public class PosUpdate : MonoBehaviour
{
    private Material _grass;

    private void Awake()
    {
        _grass = GameObject.Find("single_grass").GetComponent<Renderer>().sharedMaterial;
    }

    private void Update()
    {
        _grass.SetVector("_GlobalPos",transform.position);
    }
}