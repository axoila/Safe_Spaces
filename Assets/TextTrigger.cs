using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TextTrigger : MonoBehaviour {

	public GameObject text;

	void OnTriggerEnter(Collider other)
	{
		text.SetActive(true);
	}

	void OnTriggerExit(Collider other)
	{
		text.SetActive(false);
	}
}
