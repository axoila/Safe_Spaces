using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EverythingManager : MonoBehaviour {

	public Material everything;
	public float volumeSensitivity = 1000;
	[Range(0, 10)]public float volumeInertia = 0.1f;

	float bubbleRatio = 0;
	Transform head;

	// Use this for initialization
	void Start () {
		head = Camera.main.transform;
	}
	
	// Update is called once per frame
	void Update () {
		bubbleRatio = Mathf.MoveTowards(bubbleRatio, 1 + MicInput.MicLoudness * volumeSensitivity, 
				volumeInertia * Time.deltaTime);
		everything.SetFloat("_HeadBubble", Mathf.Pow(bubbleRatio, 2));
		everything.SetVector("_HeadPos", head.position);
	}
}
